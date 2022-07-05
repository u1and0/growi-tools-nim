# growiapi
Growi API CLI interface

Converted from Python code to Nim code
[growi-tools](git@github.com:u1and0/growi-tools.git)

## Usage

```shell-session
$ export GROWI_ACCESS_TOKEN="kjlkszk34383s=kjslldkaj4334"  # MUST SET
$ export GROWI_URL="http://localhost:3000"                 # default
$ growiapi get /path                                       # return /path's body
$ growiapi create /path/of/test "who am i"                 # create new page
$ growiapi update /path/of/test /path/of/upload.md         # markdown file ok
$ growiapi post /path/of/test "any body"                   # post subcommand is same as update if page exist.
                                                           # Or same as `create` unless page exist.
```

## growiapi help

This is a multiple-dispatch command.  -h/--help/--help-syntax is available
for top-level/all subcommands.  Usage is like:
  growiapi {SUBCMD} [subcommand-opts & args]
where subcommand syntaxes are as follows:

get [optional-params] [args: string...]
Options:
    --version      bool  false  print version
    -v, --verbose  bool  false  set verbose

post [optional-params] [args: string...]
Options:
    --version      bool  false  print version
    -v, --verbose  bool  false  set verbose

update [optional-params] [args: string...]
Options:
    --version      bool  false  print version
    -v, --verbose  bool  false  set verbose

create [optional-params] [args: string...]
Options:
    --version      bool  false  print version
    -v, --verbose  bool  false  set verbose

list [optional-params] [args: string...]
Options:
    --version      bool  false  print version
    -v, --verbose  bool  false  set verbose

rev [optional-params] [args: string...]
Options:
    --version      bool  false  print version
    -v, --verbose  bool  false  set verbose
