FROM debian:bookworm-slim

# adding /root/.local/bin is required due to ansible bin
# created by pipx in next steps 
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.local/bin:$PATH" 

RUN apt-get update && \
    apt-get install -y --no-install-recommends pipx python3 sshpass openssh-client && \
    pipx install --include-deps ansible  && \
    rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
