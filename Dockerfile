# Use Kasm's Firefox image as base - it already has everything working!
FROM kasmweb/firefox:1.15.0

USER root

# Install Tailscale and gosu (for user switching)
RUN wget -qO- https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu jammy main' | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale gosu && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories for Tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Copy custom entrypoint that starts Tailscale before Kasm services
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--tail-log"]
