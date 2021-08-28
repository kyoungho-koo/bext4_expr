#include <linux/unistd.h>
#include <stdio.h>
#include <stdlib.h>


int main(int argc, char* argv[]){
        unsigned int time = atoi(argv[1]);
	printf("time:%d\n", time);
        syscall(436, time);
        return 0;
}

