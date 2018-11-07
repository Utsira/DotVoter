<p align="center">
    <a href="http://docs.vapor.codes/3.0/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor">
        <img src="https://img.shields.io/discord/431917998102675485.svg" alt="Team Chat">
    </a>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://circleci.com/gh/vapor/api-template">
        <img src="https://circleci.com/gh/vapor/api-template.svg?style=shield" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-4.1-brightgreen.svg" alt="Swift 4.1">
    </a>
</p>

# DotVoter

### A Serverless Swift App

This repo is a proof-of-concept of a Serverless Swift App built with Vapor 3 and Swift 4.1 and deployed inside a Docker container to Now. The frontend uses the D3plus data visualization library to display the results.

DotVoter is a site that allows distributed teams to suggest issues for discussion, and then vote on which issues they'd like to discuss. Upvote an issue by tapping/ clicking on its bubble. The size and positioning of the issue allows you to easily see the most popular tickets. The clients connect to the server via a WebSocket which pushes changes to all connected peers. 

There is no database. The tickets will persist on the server only as long as there is a client connected. Note that this approach relies on there only being one instance of the server running. If the server were to scale across multiple instances, users would only be able to see the tickets on the instance that they are connected to. This "serverless" approach could be scaled though for "gameroom" use-cases where users are matched with a random selection of other players.  

For the purpose of this PoC, the backend also serves the frontend. Note though that the frontend could be a totally separate deployment.

The Dockerfile comes from the [Now examples repository](https://github.com/zeit/now-examples). See the post [A Minimal Swift Docker Image](https://medium.com/@jjacobson/a-minimal-swift-docker-image-b93d2bc1ce3c) for more details on how the Dockerfile works.