
casync application container
----------------------------

*This is not an "official" project and not part of casync or systemd*

It solved my problem, if it's useful for someone else that's great.

----

**Why?**

I kept running into issues with wanting [casync](https://github.com/systemd/casync) 
on old systems that do not provide a package for it.

I then found that compiling casync from source is a challenge because it
has so many modern dependencies, in recent versions.  Even once most libs
and build tools have been handled, dependencies can even extend down to a
libc version being too old on the old distro, and I'm not up for messing
with those details on a system in production.

So I use this "application container" as a stopgap solution, since I **do**
usually have Docker on those older machines.


The **Dockerfile** is trivial of course (see also DesignNotes.txt) and the
useful stuff I guess is mostly the content of the **Makefile** and the
defaults given there for the "make run" command.

Author
------
(C) 2018 Gunnar Andersson

License
-------
Your choice of MPLv2 (license text [provided](https://github.com/gandaman/casync-docker/blob/master/LICENSE)), GPLv2 or GPLv3.

Contributing
------------

- Send a Pull Request here on GitHub for master branch.
- Agree that you are contributing under the project's original license
- Sign your commit

I might miss it and not answer quickly - and in that case you can look up my
email (if you know where to find me) and let me know.  Otherwise, please be
patient.

Dependencies
------------
- Docker and (GNU) make.

Building Docker Image
---------------------

- View the Makefile to see the environment variables.
- Edit the variables to your liking or override temporarily by exporting new values in your environment.

Then:

```
make build
```

Running casync
--------------

The Makefile is there to do the heavy lifting also for running.

Environment variables are used to get arguments into the Makefile.

There are three separate bind mounts possible from host to container:
You will need at least one, but they all default to the directory you
are currently in ($PWD) if not specified.

- WORK_DIR
- OUTPUT_DIR
- INPUT_DIR

They are mounted on /workdir, /outputdir and /inputdir respectively.

The casync command is placed into
- CASYNC_ARGS

A shell script would be even more convenient here, and if you create it
please send me a copy or pull request :)  -- see TODOs for some info


Examples
--------

Run casync --help

```bash
CASYNC_ARGS=--help make run
```

or if the order makes more sense to you:
```
make run CASYNC_ARGS="--help"
```
OK, let's look at some more.

*NOTE* On the next two examples don't get confused by the fact that
"**make**" is one of the verbs (commands) given to the casync binary,  and
that we also write "make" to call the Makefile.  The second make is just the
command actually passed to casync.

"casync make" to create a **catar archive** of /usr of the container itself (not that useful, but it's a simple example)

```
make run CASYNC_ARGS="make /workdir/usr.catar /usr"
: Remember /workdir defaults to your current directory on the host
: The created file is now here, on your host:
ls -l ./usr.catar
```

"casync make" to create a **casync index** of the same:
and store the casync store in ./mystore/
```
make run CASYNC_ARGS="make /workdir/usr.caidx --store=/workdir/mystore /usr"
```

Create a casync index of your the Photos folder in /mnt/networkdisk
and put the corresponding data store in $HOME/backupstore/.
In this example, using export to set environment first instead of a temporary assignment

```
export INPUT_DIR=/mnt/networkdisk
export WORK_DIR=/home/myself/
export OUTPUT_DIR=/home/myself/backupstore
export CASYNC_ARGS="make /workdir/Photos.caidx --store=/outputdir/Photos.castr /inputdir/Photos/"
make run
```

Restore the previously created casync index of your Photos folder to
$HOME/temp_pictures.  This time we are more lazy and just use the
/workdir for input and output paths, and we rely on that work dir defaults
to our current working directory

```
unset INPUT_DIR WORK_DIR OUTPUT_DIR # (Reset your env, just in case you used export above)
cd $HOME
mkdir temp_pictures  # Target dir should exist
: Note $WORK_DIR is empty and will therefore default to current directory on host ($HOME)
export CASYNC_ARGS="extract --store=/workdir/backupstore/Photos.castr /workdir/backupstore/Photos.caidx /workdir/temp_pictures"
make run
```

Obviously the store can be an online store, and there are many other options.
Please refer to casync resources for more information. 

Troubleshooting
---------------

*Failed to run synchronizer: Permission denied*

1. You might have forgot to created one of the mount directories, such as OUTPUT_DIR?
If the directory does not exist it tends to be created by docker before mounting
and it then ends up being owned by root, so casync cannot write to it.
(Note that casync is run with a user ID equal to your own on host, in order
 to make sure the written files are also owned by your user)

2. Other weird permission issues are usually SELinux related, if you are running a distro
that uses SELinux.  The container itself might be not allowed to write (or
even read) to the mounted host directory. Please google "docker selinux
permission denied" or similar for some references.

In some cases you might run into that SElinux attributes have been stored
in the casync archive, and may not be supported in the extract environment
or other issues. (Read the manual - casync is super strict about
reproducibility).  If you don't care about it and just want the files
you could try --without=selinux on either the archiving or extracting
step.


Bugs/unsupported
----------------

- **casync mount** has not been implemented but it might be possible -- see TODOs
- Networking not really tested yet (such as an online store)- please try and report back
- There is no man installed.  Of course the container is not made to be interactive, but it could be useful to have it on the image and support a way to view it. Here is an [online man page](https://man.cx/casync)

TODOs
-----

1. Shrink container, use for example Alpine Linux -- see DesignNotes.txt

2. Create a shell script that wraps the somewhat ugly "make run" command.
Something like:

```
./casync <casync arguments...>
```

I like having everything about a contatiner in single a Makefile as a
starting point, but this script would help usability. Personally I rarely
run casync manually in the shell anyway, so it will be called from some
other shell script and then user-friendliness becomes less of an issue, but
it would be nicer.

Note however if the wrapper is to mimic the standard casync binary and
the arguments refer to local (host) files instead of the mounts in the
container, then it would have to figure out which host dirs to bindmount
and fiddle with the arguments.  Just providing the entire host VFS in the
container might be too crude...  Or is that the way to go?

3. Not supporting **casync mount** yet.  It would be nice to have a container
that is detached but keeps running, which takes care of the mount and makes
it available to the host.  Not sure if there are any obstacles to that...
Maybe you will try it, and send me a pull request?

4. Others?
Any idea you might have.  For example I'd happily support some other
runtime than docker (and rename accordingly)

- **rkt**
- A **systemd-nspawn** setup (I guess it's a small subset of systems that support systemd-nspawn but not casync, but who knows)
- ...

References
----------

Another way to go might be [desync](https://github.com/folbricht/desync).


