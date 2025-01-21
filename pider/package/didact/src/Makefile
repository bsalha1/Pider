OBJS = didact.o

all: $(OBJS)
	$(CXX) $(CXX_FLAGS) $^ -o didact

%.o: %.cc
	$(CXX) $(CXX_FLAGS) -c $< -o $@
