# Host-side tests for fan_logic.h (no Arduino needed). Run: make -C fume-extractor/firmware/test
# AddressSanitizer hangs at startup on recent macOS, so it's Linux-only.
SAN := $(if $(filter Darwin,$(shell uname -s)),-fsanitize=undefined,-fsanitize=address,undefined)

test_fan_logic: test_fan_logic.cpp ../fume_extractor/fan_logic.h
	g++ -std=c++17 -O0 -g -Wall -Wextra $(SAN) -I../fume_extractor -o test_fan_logic test_fan_logic.cpp
	./test_fan_logic
clean:
	rm -rf test_fan_logic test_fan_logic.dSYM
