<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Audio Player</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />

    <script src="${asset.assetPath(src: 'audiojs/audio.min.js')}"></script>
    <script>
        audiojs.events.ready(function() {
            audiojs.createAll();
        });
    </script>
    <style>
    body {
        padding: 0;
        margin: 0;
        display: flex;
        align-items: center;
    }
    html, body {
        height: 100%;
    }

    .container {
        height: auto;
        margin: auto;
    }
    </style>
</head>
<body>
    <div class="container">
        <audio src="${params.file}" preload="auto"></audio>
    </div>
</body>
</html>