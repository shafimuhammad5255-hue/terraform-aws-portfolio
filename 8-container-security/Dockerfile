# Intentionally using an older python base image to demonstrate vulnerability scanning
FROM python:3.8-slim

WORKDIR /app

RUN pip install flask==2.0.1

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]