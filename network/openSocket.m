function t = openSocket(ip, port)
    
    t = tcpip(ip, port, 'NetworkRole', 'client');
    fopen(t);
end