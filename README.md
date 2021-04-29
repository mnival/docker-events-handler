INSTALL
============

```
git clone https://github.com/mnival/docker-events-handler.git
cd docker-events-handler
ln -s $(pwd)/docker-events-handler /usr/local/bin/
ln -s $(pwd)/etc/docker-events-handler /etc/
ln -s $(pwd)/docker-events-handler.service /etc/systemd/system/
systemctl enable docker-events-handler.service
systemctl start docker-events-handler.service
```
