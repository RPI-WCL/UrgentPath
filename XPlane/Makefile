all: clean xplane9 xplane11

COMPILER = g++

clean:
	rm -f *.out

xplane9: udp_redirect_xplane9.cpp
	$(COMPILER) udp_redirect_xplane9.cpp -Wall -o udp_redirect_xplane9.out

xplane11: udp_redirect_xplane11.cpp
	$(COMPILER) udp_redirect_xplane11.cpp -Wall -o udp_redirect_xplane11.out
