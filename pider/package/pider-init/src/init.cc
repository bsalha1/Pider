#include <cstdio>
#include <cstdlib>
#include <cerrno>
#include <sys/mount.h>
#include <sys/wait.h>
#include <unistd.h>
#include <syslog.h>
#include <stdbool.h>

bool init()
{
    /*
     * Hello world.
     */
    printf("initializing pider\n");

    /*
     * Mount the bare minimum, the kernel already mounts devtmpfs for us.
     */
    if (mount("proc", "/proc", "proc", 0, NULL) != 0)
    {
        perror("failed to mount proc");
        return false;
    }
    if (mount("sysfs", "/sys", "sysfs", 0, NULL) != 0)
    {
        perror("failed to mount sysfs");
        return false;
    }

    /*
     * Set hostname.
     */
    if (sethostname("pider", sizeof("pider") - 1) != 0)
    {
        perror("failed to set hostname to pider");
        return false;
    }

    /*
     * Start syslogd so further logs do not go to serial. Do this in a blocking vfork() to avoid
     * overhead of copying page tables and syslogd goes to background quickly.
     */
    const pid_t syslogd_pid = vfork();
    if (syslogd_pid < 0)
    {
        perror("failed to vfork syslogd");
        return false;
    }

    /*
     * In child, execute syslogd.
     */
    if (syslogd_pid == 0)
    {
        if (execl("/sbin/syslogd", "syslogd", NULL) != 0)
        {
            perror("failed to execute /sbin/syslogd");
            _exit(EXIT_FAILURE);
        }
        _exit(EXIT_SUCCESS);
    }

    /*
     * Allow login over serial. Called in asynchronous child process since it blocks.
     */
    const pid_t getty_pid = fork();
    if (getty_pid < 0)
    {
        perror("failed to vfork getty");
        return false;
    }

    if (getty_pid == 0)
    {
        if (execl("/sbin/getty", "getty", "-L", "console", "0", "vt100", NULL) != 0)
        {
            perror("failed to put getty on console");
            _exit(EXIT_FAILURE);

        }

        _exit(EXIT_SUCCESS);
    }

    /*
     * Open a pipe to capture output of future processes and send to syslog.
     */
    int syslog_pipe_fd[2];
    if (pipe(syslog_pipe_fd) != 0)
    {
        perror("failed to create syslog pipe");
        return false;
    }

    /*
     * Execute initialization script. Do this in a blocking vfork() to avoid overhead of copying
     * page tables and this script terminates quickly.
     */
    const pid_t init_sh_pid = vfork();
    if (init_sh_pid < 0)
    {
        perror("failed to vfork init.sh");
        close(syslog_pipe_fd[0]);
        close(syslog_pipe_fd[1]);
        return false;
    }

    /*
     * In child, execute init.sh.
     */
    if (init_sh_pid == 0)
    {
        int exit_code = EXIT_FAILURE;

        /*
         * Close unused read end.
         */
        close(syslog_pipe_fd[0]);

        /*
         * Redirect stdout and stderr to pipe write end.
         */
        if (dup2(syslog_pipe_fd[1], STDOUT_FILENO) < 0)
        {
            perror("failed to redirect stdout to syslog pipe");
            goto exit_init_sh;
        }
        if (dup2(syslog_pipe_fd[1], STDERR_FILENO) < 0)
        {
            perror("failed to redirect stderr to syslog pipe");
            goto exit_init_sh;
        }

        /*
         * Execute the initialization script.
         */
        if (execl("/bin/sh", "sh", "/bin/init.sh", NULL) != 0)
        {
            perror("failed to execute /bin/init.sh");
            goto exit_init_sh;
        }

        exit_code = EXIT_SUCCESS;

    exit_init_sh:
        close(syslog_pipe_fd[1]);
        _exit(exit_code);
    }

    /*
     * Close unused write end.
     */
    close(syslog_pipe_fd[1]);

    /*
     * Wait for script to finish.
     */
    if (waitpid(init_sh_pid, NULL, 0) == -1)
    {
        perror("failed to wait for init.sh to finish");
        close(syslog_pipe_fd[0]);
        return false;
    }

    /*
     * Read child output from pipe into syslog.
     */
    char buffer[128];
    ssize_t bytes_read;
    while ((bytes_read = read(syslog_pipe_fd[0], buffer, sizeof(buffer) - 1)) > 0)
    {
        buffer[bytes_read] = '\0';
        syslog(LOG_INFO, "%s", buffer);
    }

    close(syslog_pipe_fd[0]);

    return true;
}

int main(int argc, char **argv)
{
    if (!init())
    {
        fprintf(stderr, "failed to initialize\n");
    }

    for (;;)
    {
        /*
         * Wait for signal that terminates us or invokes a signal handler.
         */
        pause();
    }

    return 0;
}