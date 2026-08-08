FROM alpine:3.20

RUN apk add --no-cache openssh-server && \
    ssh-keygen -A && \
    adduser -D -s /bin/ash ciuser && \
    mkdir -p /home/ciuser/.ssh && \
    chmod 700 /home/ciuser/.ssh && \
    chown -R ciuser:ciuser /home/ciuser/.ssh

# Disable root login and password auth by default — key-based only.
# Override at container runtime if a specific pipeline job genuinely needs
# password auth (it shouldn't).
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
