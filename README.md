# crunch
Crunch is used to bundle folders of code using `require` into a single executable file. This file will then be able to load the embedded modules as if it were in its original directory structure.

## Usage
`crunch <project root> [output file]`

`project root` is the root directory of the project. `main.lua` should exist within this directory, and it will be used as the root for resolving modules when `require` is used. The contents will be recursively embedded into the bundle.

`output file` is the location to write the output to. It defaults to `bundle.lua`.
