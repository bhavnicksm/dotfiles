# Bhavnick's Dotfiles

Yes, I have my own dotfiles :) 
And, I think they are pretty cool too. 


## Stow set-up

If you have `GNU stow` on your system, you can run `stow` to symlink the files here, like below:

```bash
stow -v ./neovim 
```

## Manual set-up

Sometimes, `stow` doesn't work properly, in which case, I use the `link_*.sh` files, for example: 

```bash 
bash link_nvim.sh
```

These files do a manual link from the current file to the required file, without any dependencies to `stow`, which is awesome. 


## Neovim

I <3 Neovim.

I use it with a bunch of tools like treesitter, lsp, telescope etc along with a cool them from catppuccine.


## License

These dotfiles are MIT licensed, so feel free to use them however you like. Though some acknowledgement would be nice :)



