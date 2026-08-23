'use client';

import { useRef, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useToast } from './Toast';

const BUCKET = 'product-images';
const MAX_BYTES = 5 * 1024 * 1024; // 5 MB
const ALLOWED = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
const MAX_DIM = 1200;

/** Downscale large images client-side before upload (no extra dependency). */
async function compress(file: File): Promise<Blob> {
  if (file.type === 'image/webp') return file; // keep webp as-is
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, MAX_DIM / Math.max(bitmap.width, bitmap.height));
  if (scale === 1) return file;
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  const ctx = canvas.getContext('2d')!;
  ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  return await new Promise<Blob>((resolve) =>
    canvas.toBlob((b) => resolve(b ?? file), 'image/jpeg', 0.85),
  );
}

export function ImageUploader({
  value,
  onChange,
  label = 'Image',
}: {
  value: string;
  onChange: (url: string) => void;
  label?: string;
}) {
  const { show } = useToast();
  const inputRef = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);

  async function handleFile(file: File) {
    if (!ALLOWED.includes(file.type)) {
      show('Only JPG, PNG or WebP images are allowed.', 'error');
      return;
    }
    if (file.size > MAX_BYTES) {
      show('Image must be 5 MB or smaller.', 'error');
      return;
    }
    setBusy(true);
    try {
      const supabase = createClient();
      const blob = await compress(file);
      const ext = file.type === 'image/png' ? 'png' : file.type === 'image/webp' ? 'webp' : 'jpg';
      const path = `products/${crypto.randomUUID()}.${ext}`;
      const { error } = await supabase.storage.from(BUCKET).upload(path, blob, {
        cacheControl: '3600',
        upsert: false,
        contentType: blob.type || file.type,
      });
      if (error) throw error;
      const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
      onChange(data.publicUrl);
      show('Image uploaded.', 'success');
    } catch (e: any) {
      show(e?.message ?? 'Upload failed.', 'error');
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    // Best-effort delete of the stored object if it belongs to our bucket.
    if (value.includes(`/${BUCKET}/`)) {
      try {
        const supabase = createClient();
        const path = value.split(`/${BUCKET}/`)[1];
        if (path) await supabase.storage.from(BUCKET).remove([path]);
      } catch {
        /* ignore — orphan cleanup is best-effort */
      }
    }
    onChange('');
  }

  return (
    <div>
      <span className="label">{label}</span>
      <div className="flex items-center gap-4">
        <div className="flex h-24 w-24 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-dashed border-gray-300 bg-gray-50">
          {value ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={value} alt="preview" className="h-full w-full object-cover" />
          ) : (
            <span className="text-xs text-gray-400">No image</span>
          )}
        </div>
        <div className="space-y-2">
          <input
            ref={inputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) handleFile(f);
              e.target.value = '';
            }}
          />
          <button
            type="button"
            className="btn-secondary"
            disabled={busy}
            onClick={() => inputRef.current?.click()}
          >
            {busy ? 'Uploading…' : value ? 'Replace' : 'Upload'}
          </button>
          {value && (
            <button type="button" className="btn-secondary ml-2 text-red-600" onClick={remove}>
              Remove
            </button>
          )}
          <p className="text-xs text-gray-400">JPG, PNG, WebP · max 5 MB</p>
        </div>
      </div>
    </div>
  );
}
