<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

final class UploadStorage
{
    public static function disk(): string
    {
        return (string) config('filesystems.uploads', 'public');
    }

    public static function storePublicUrl(UploadedFile $file, string $directory): array
    {
        $disk = self::disk();
        $path = $file->store($directory, $disk);

        return [
            'path' => $path,
            'url' => Storage::disk($disk)->url($path),
        ];
    }
}
