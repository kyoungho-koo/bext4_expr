#include <linux/unistd.h>
#include <stdio.h>
#include <stdlib.h>


int main(int argc, char* argv[]){
        unsigned int mode = atoi(argv[1]);
        syscall(436, mode);
        return 0;
}


