OBJS = init.o

CXXFLAGS = -Wall -Werror

all: $(OBJS)
	$(CXX) $(CXXFLAGS) $^ -o init

%.o: %.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@
