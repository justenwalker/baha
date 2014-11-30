Baha 
=======

[![Gem Version](https://badge.fury.io/rb/baha.png)](http://badge.fury.io/rb/baha)
[![Build Status](https://travis-ci.org/justenwalker/baha.png?branch=master)](https://travis-ci.org/justenwalker/baha)

Introduction
------------

Baha is a command-line utility that assists in the creation of docker images.
It addresses some of Dockerfiles shortcomings and encourages smaller, reusable, tagged images.

Why not Dockerfiles?
--------------------

Dockerfiles are simple. They are an easy way to make a docker image without needing any other dependencies. However, their simplicity comes at a cost: redundancy.  This redundancy is present in a few ways that make more complicated images difficult to make and maintain.

So why would I use Baha?
------------------------

Baha attempts to address the shortcomings of Dockerfiles by factoring out redundancies and providing a modular interface for creating suites of dependent images.

### 1. Baha forbids more than 1 layer per image

If you split statements across multiple `RUN` statements, each of these results in a new layer.
The more commands you run, the more layers you create.  If you want to *minimize the number of layers* (See [Official Recommendations](https://docs.docker.com/articles/dockerfile_best-practices/)) 
then you must ensure that all statements can be condensed into one line - sacrificing maintainability in the process.

Baha encourages using scripts instead of `RUN` statements to ensure that only one layer is created per image.

### 2. Baha encourages smaller images

The nature of the way the dockerfiles are processed means that each command you run commits a new image.
This means, that if you have a `RUN` statement that downloads packages for installation. 
This will commit a layer with the installation files.  Later on if you clean up these files with further `RUN` commands, they will still exist in your image lineage - thus having no space savings. Without proper precautions, you'll end up having unnecessarily large images.

Baha ensures that all setup tasks happen in a single commit - so you can write cleanup statements and be assured that they will indeed be absent in the resulting images.

### 3. Baha understands the bigger picture

Another best practice ([2](http://crosbymichael.com/dockerfile-best-practices-take-2.html): #7) recommends that you use your own base image.
Dockerfiles make it simple to create your own 'base' image, but how about updates?

If you were to just rebuild all of your Dockerfiles, you would create an entirely new tree - even if nothing changed.

Baha will rebuild your entire lineage if the base image changes, but will not rebuild base images if only the children change.

**Caveat**

Baha relies on tagging your releases, noticing when the tag has changed, and treating tags as immutable. 
This is analogous to how **git** treats tags.

Tagging your images is another best-practice ([2](http://crosbymichael.com/dockerfile-best-practices-take-2.html): #5) anyway, so this is encouraged by design. 

Bottom line is: If you change your image, you should change the tag/version.

#### 4. Baha lets you cache build dependencies

Most of the time, dependencies are downloaded and installed in the context of the docker container itself.
This means that rebuilding an image results in redundant downloads if files haven't changed.

Baha has pre-build steps that can be used to download files and prepare scripts on host machine.
This workspace is made available to the image via a bind mount during build-time. Not only do these dependencies stick around between builds, but they do not need to be cleaned up after the image is committed, since they are never persisted to the container.

**References**

1. [Official Dockerfile Best Practices](https://docs.docker.com/articles/dockerfile_best-practices/)
2. [Dockerfile Best Practices - take 2, by Michael Crosby](http://crosbymichael.com/dockerfile-best-practices-take-2.html)

Disclaimer
----------

This gem was just released (pre 1.0) and is not ready for production use yet.

During pre 1.0, things may change that break backwards compatibility between releases. Most likely these breaking
changes would be related to the YAML file syntax.

To Do
-----
See the [Issue Tracker](https://github.com/justenwalker/baha/issues)

Installation
------------

```
$ gem install baha
```
### gem install baha

Usage
-----

```
Baha Commands:
  baha build [options] CONFIG  # Builds all docker images based on the given config
  baha help [COMMAND]          # Describe available commands or one specific command
  baha version                 # Print version and exit
```

**build**

```
Usage:
  baha build [options] CONFIG

Options:
      [--logfile=LOGFILE]         # Log output to LOGFILE. Omit to log to stdout.
  d, [--debug], [--no-debug]      # Toggle debug logging. Includes verbose.
  v, [--verbose], [--no-verbose]  # Toggle verbose logging
  q, [--quiet], [--no-quiet]      # Suppress all logging

Description:
  Reads the CONFIG file and builds all of the docker images in the order they appear.
```

Check out the **example** directory for a sample CONFIG.

How it works
------------

Baha will read a config.yml file first and load each image configuration.
It will build each image in the order they appear by doing the following.

### Check if the image needs updating
1. Check to see if the parent image changed
2. Check to see if the tag does not exist in the repository

### Prepare the image's workspace (bind mount)
1. Create the workspace directory if it doesn't exist
2. Run any `pre_build` tasks to prepare dependencies

### Run the command inside the image
1. Creates a new container and runs it with the `command` given
2. Commits the container with the run options specified in the images `config` section.

### Tags the resulting image
Adds the appropriate tags to the image as defined in the image config for both the remote registry and local repository.

How to Contribute
-----------------

Contributions are welcome! Documentation, bug-fixes, patches, or new functionality, or comments/criticism.

### Code Contributions

Start by [forking](https://github.com/justenwalker/baha/fork) the github project.
Work on a topic branch instead of master (`git checkout -b my-feature`) and submit a pull request when you are done.

Please add specs to cover the change so that we can avoid regressions and help future commits from breaking existing code.

### Running the tests

    $ bundle
    $ bundle exec rake spec

### Installing locally

    $ bundle
    $ [bundle exec] rake install

### Reporting Issues

Please include a reproducible test case if possible. Otherwise, provide as much detail as you can.

License
-------

Copyright (c) 2014 Justen Walker.

Released under the terms of the MIT License. For further information, please see the file `LICENSE.md`.
