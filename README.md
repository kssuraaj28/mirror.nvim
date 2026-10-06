# Mirrorig an nvim buffer to another nvim instance
A lua library to mirror another vim buffer (the provider) to another nvim instance (the viewer)

## How to setup
You need to know the nvim provider's socket name. 
Either read `v:servername`, or start the instance using `nvim --listen <servername path>`

## How to mirror
This library module has the following methods
- `mirror (server_path, buffer_no)`: Mirror a remote server buffer in a new scratch buffer
- `stop_mirroring()`:  Stop mirroring
