## Builds in appx 7.5secs

FROM python:3-alpine
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir flask requests
RUN apk update && apk add aws-cli kubectl jq
EXPOSE 5000
CMD ["python", "weather.py"]