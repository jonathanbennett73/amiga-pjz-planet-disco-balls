@ECHO OFF

REM Detect crop. Use "Enable Capture Before Filtering Option in WinUAE then find part
REM of demo that has the biggest screen. From my own 352x272 testing this is:
REM crop=704:544:44:20
REM ffplay -i "output.avi" -vf "cropdetect=24:16:0"
REM exit /b 0

REM https://scribbleghost.net/2018/10/26/youtube-recommended-encoding-settings-for-ffmpeg/
REM Use lagarith lossless for video
REM Use PCM 16bit/48000 for audio

REM ffmpeg -i "output.avi" -vf "crop=712:548:40:18,scale=iw*4:ih*4:flags=neighbor" -c:a aac -b:a 320k -c:v libx264 -crf 10 -profile:v high -level 4.0 -preset slow -pix_fmt yuv420p -f matroska "output.mkv"
REM ffmpeg -i "output.avi" -vf "crop=712:548:50:18,scale=iw*4:ih*4:flags=neighbor" -c:a aac -b:a 320k -c:v libx264 -crf 10 -profile:v high -level 4.0 -preset slow -pix_fmt yuv420p -f matroska "output.mkv"

REM Copy audio, super high profile
REM ffmpeg -i "output.avi" -vf "crop=712:548:50:18,scale=iw*4:ih*4:flags=neighbor" -c:a copy -c:v libx264 -crf 1 -preset veryslow -pix_fmt yuv420p -f matroska "output.mkv"

REM Lossless
ffmpeg -i "output.avi" -vf "crop=704:544:44:20,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" -c:a copy -c:v libx264 -crf 0 -preset veryfast -coder 1 -pix_fmt yuv420p -f matroska "output_lossless_50fps.mkv"

REM Youtube recommended
REM ffmpeg -i "output.avi" -vf "crop=712:544:50:20,scale=iw*4:ih*4:flags=neighbor" -c:a aac -b:a 320k -ar 48000 -c:v libx264 -crf 1 -profile:v high -level 4.0 -preset slow -bf 2 -coder 1 -b:v 15M -r 50 -pix_fmt yuv420p -threads 8 -cpu-used 0 -f matroska "output_youtube.mkv"
REM ffmpeg -i "output.avi" -vf "crop=704:544:44:20,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" -c:a aac -b:a 320k -ar 48000 -c:v libx264 -crf 1 -profile:v high -level 4.0 -preset slow -bf 2 -coder 1 -b:v 15M -r 50 -pix_fmt yuv420p -threads 8 -cpu-used 0 -f matroska "output_youtube_50fps.mkv"
REM ffmpeg -i "output.avi" -vf "fps=fps=30,crop=704:544:44:20,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" -c:a aac -b:a 320k -ar 48000 -c:v libx264 -crf 1 -profile:v high -level 4.0 -preset slow -bf 2 -coder 1 -b:v 15M -r 50 -pix_fmt yuv420p -threads 8 -cpu-used 0 -f matroska "output_youtube_30fps.mkv"

