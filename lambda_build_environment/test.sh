#docker run -it --mount type=bind,source="../slack_chatbot/SlackLambdaInbound",target=/app awspy3.8:latest bash
#docker run -it --mount type=bind,source="$(pwd)/account_creation/AccountCreationLambda",target=/app awspy3.8:latest
docker run -it --mount type=bind,source="$(pwd)/email_validation/EmailVerificationLambda",target=/app awspy3.8:latest