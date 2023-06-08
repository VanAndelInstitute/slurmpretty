docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: PidsLimit={{ .HostConfig.PidsLimit }}'
