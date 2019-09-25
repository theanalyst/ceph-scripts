#!/usr/bin/python


import sys, getopt


usage="rbdtop.sh [OPTIONS]\nwhere:\n\t-h show this help\n\t-o <id> check osd <id> only\n\t-l <len> logs gathering period (default 30s)\n\t-v increase verbosity\n"


def main(argv):
    print argv
    try:
        opts, args = getopt.getopt(argv, "qho:l:")
    except:
        print usage;  
    for opt, arg in opts:
        if opt == '-h':
            print usage;
            sys.exit()
        elif opt == '-q':
            print "-q found"
        elif opt == '-o':
            print "-o found "+arg
        elif opt == '-l':
            print "-l found"+arg
            # do crazy shit




if __name__ == "__main__":
   main(sys.argv[1:])
