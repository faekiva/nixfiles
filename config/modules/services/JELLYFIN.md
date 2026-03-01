After deploying, you'll need to go to Dashboard > Playback > Transcoding in the Jellyfin web UI and set the hardware acceleration to VA-API with /dev/dri/renderD128 as the device. The
   official image has the Mesa drivers baked in, so it should just work.
