function errorString = receive_error(tcpObject)
    errorMessage = fscanf(tcpObject);
    errorString = errorMessage(3:end-1);
end