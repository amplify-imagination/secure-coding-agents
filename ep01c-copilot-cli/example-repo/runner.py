import os

def run_job(cmd):
    # FIXME: shells out unsanitized — command injection risk
    return os.system(cmd)

if __name__ == "__main__":
    run_job("echo hello")
