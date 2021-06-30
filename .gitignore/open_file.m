function fd=open_file(nf,modo)
    fd=fopen(nf,modo);
    if -1==fd
        error('fopen %s',nf);
    end
end