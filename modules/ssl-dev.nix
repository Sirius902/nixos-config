{pkgs, ...}: {
  systemd.timers."generate-dev-cert-timer" = {
    description = "Regenerate self-signed SSL certificate annually";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "yearly";
      Unit = "generate-dev-cert.service";
    };
  };

  systemd.services."generate-dev-cert" = {
    description = "Generate self-signed SSL certificate for localhost";
    path = [pkgs.openssl];
    script = ''
      mkdir -p /persist/ssl/
      ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 365 \
                      -newkey rsa:2048 -keyout /persist/ssl/localhost.key -out /persist/ssl/localhost.crt \
                      -subj '/CN=localhost'

      chown chris:users /persist/ssl/localhost.key
      chmod 600 /persist/ssl/localhost.key
    '';

    # Ensure the certificate exists before other services start
    before = ["network.target"];
  };

  security.pki.certificates = [
    "/persist/ssl/localhost.crt"
  ];

  environment.sessionVariables = {
    SSL_DEV_CERT = "/persist/ssl/localhost.crt";
    SSL_DEV_KEY = "/persist/ssl/localhost.key";
  };
}
