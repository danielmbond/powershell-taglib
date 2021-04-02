filter get-artist([string]$artist) {
    $tag = [TagLib.File]::Create($_.fullname)
    if ($tag.Tag.AlbumArtists) {
        return $tag.Tag.AlbumArtists
    } elseif ($tag.Tag.Performers) {
        return $tag.Tag.Performers
    } else {
        return ""
    }
}

filter save-picture([string]$outfile) {
    $tag = [TagLib.File]::Create($_.fullname)
    if ($tag.Tag.Pictures) {
        $fileName = $tag.Tag.Pictures.Filename
        $mimetype = $tag.Tag.Pictures.MimeType
        switch ($mimetype)
        {
            "image/bmp"  {$extension = "bmp"}
            "image/jpeg" {$extension = "jpg"}
            "image/png"  {$extension = "png"}
            Default      {$extension = $false}
        }
        if ($extension -and $extension -ne "jpg") {
            $outfile = $outfile.Replace(".jpg",".$extension")
        }
        $tag.Tag.Pictures.data | Set-Content -Path $outfile -Encoding Byte
        $tag.Dispose()
        return $outfile
    } else {
        return $false
    }
}

function GetPictureFromBitmap([System.Drawing.Bitmap]$bitmap)
{
    $converter = New-Object -TypeName System.Drawing.ImageConverter
    $byte_vec = New-Object -TypeName TagLib.ByteVector -ArgumentList $converter.ConvertTo($bitmap, [byte[]])
    $picture = New-Object -TypeName TagLib.Picture -ArgumentList $byte_vec
    $picture_list = New-Object TagLib.IPicture[] 1
    $picture_list[0] = $picture
    return $picture_list
}

filter set-picture([string]$picpath) {
    $tag = [TagLib.File]::Create($_.fullname)
    try {
        # Load picture into System.Drawing.Image
        [System.Drawing.Bitmap]$pic = [System.Drawing.Image]::FromFile($picpath)
        # Add picture to MP3
        $tag.Tag.Pictures = GetPictureFromBitmap($pic)
        # Save Mp3 
        $pic.Dispose()
        $tag.Save()
        $tag.Dispose()
        $pic.Dispose()
        $pic = $null
        $tag = $null
        return $true
    } catch {
        return $false
    }
}

filter set-artist([string]$artist) {
    $tag = [TagLib.File]::Create($_.fullname)
    $tag.Tag.AlbumArtists = $artist
    $tag.Tag.Performers = $artist
    $tag.Save()
}

filter get-title([string]$title) {
    $tag = [TagLib.File]::Create($_.fullname)
    return $tag.Tag.Title
}

filter set-title([string]$title) {
    $tag = [TagLib.File]::Create($_.fullname)
    $tag.Tag.Title = $title
    $tag.Save()
}

filter get-album([string]$album) {
    $tag = [TagLib.File]::Create($_.fullname)
    return $tag.Tag.Album
}    

filter set-album([string]$album) {
    $tag = [TagLib.File]::Create($_.fullname)
    $tag.Tag.Album = $album
    $tag.Save()
}    

filter get-track([int]$track) {
    $tag = [TagLib.File]::Create($_.fullname)
    return $tag.Tag.Track
}

filter set-track([int]$track, [int]$trackCount = 0) {
    $tag = [TagLib.File]::Create($_.fullname)
    $tag.Tag.Track = $track
    $tag.Tag.TrackCount = $trackCount
    $tag.Save()
}    

filter get-disc([int]$disc, [int]$discCount = 0) {
    $tag = [TagLib.File]::Create($_.fullname)
    return $tag.Tag.Track
}    

filter set-disc([int]$disc, [int]$discCount = 0) {
    $tag = [TagLib.File]::Create($_.fullname)
    $tag.Tag.Track = $disc
    $tag.Tag.TrackCount = $discCount
    $tag.Save()
}    

function update-trackAndDisc([string]$match = "D(?<disc>[0-9]+)T(?<track>[0-9]+)")
{
    begin {
        $total = 0
        $discs = @{}
    }
    process {
        if ($_.fullname -match $match) {
            $disc = $matches["disc"]
            $track = $matches["track"]
            if( $discs[$disc] ) { $tags = $discs[$disc] } else { $tags = @() }
            $tagFile = [TagLib.File]::Create($_.fullname)
            $tagFile.Tag.Track = $track
            $tagFile.Tag.Disc = $disc
            $tags += $tagFile
            $discs[$disc] = $tags
            $total++
        }
    }
    end {
        foreach ($key in $discs.keys) {
            $tags = $discs[$key]
            $trackCount = $tags.length
            
            foreach ($tagFile in $tags) {
                $tagFile.Tag.TrackCount = $trackCount;
                $tagFile.Tag.DiscCount = $discs.keys.count
                $tagFile.Save()
            }
        }
    }
}
