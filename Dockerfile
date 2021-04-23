FROM gcr.io/uwit-mci-axdd/django-container:1.3.1 as app-prewebpack-container

USER root
RUN apt-get update && apt-get install mysql-client libmysqlclient-dev -y
USER acait

ADD --chown=acait:acait app_name/VERSION /app/app_name/
ADD --chown=acait:acait setup.py /app/
ADD --chown=acait:acait requirements.txt /app/

RUN . /app/bin/activate && pip install -r requirements.txt
RUN . /app/bin/activate && pip install mysqlclient

ADD --chown=acait:acait . /app/
ADD --chown=acait:acait docker/app_deploy.sh /scripts/app_deploy.sh
ADD --chown=acait:acait docker/app_start.sh /scripts/app_start.sh
ADD --chown=acait:acait docker/ project/
RUN chmod u+x /scripts/app_deploy.sh
RUN . /app/bin/activate && pip install django-webpack-loader


FROM node:14.5.0-stretch AS wpack
ADD . /app/
WORKDIR /app/
RUN npm install .
RUN npx webpack --mode=production

FROM app-prewebpack-container as app-container


COPY --chown=acait:acait --from=wpack /app/app_name/static/app_name/bundles/* /app/app_name/static/app_name/bundles/
COPY --chown=acait:acait --from=wpack /app/app_name/static/ /static/
COPY --chown=acait:acait --from=wpack /app/app_name/static/webpack-stats.json /app/app_name/static/webpack-stats.json


FROM gcr.io/uwit-mci-axdd/django-test-container:1.3.1 as app-test-container

COPY --from=app-container /app/ /app/
COPY --from=app-container /static/ /static/
