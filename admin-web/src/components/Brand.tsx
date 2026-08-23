export function BrandMark({ size = 40 }: { size?: number }) {
  return (
    <div
      className="flex items-center justify-center rounded-xl font-extrabold tracking-tight text-white"
      style={{
        width: size,
        height: size,
        fontSize: size * 0.38,
        background: 'linear-gradient(135deg, #5E9C2C, #3D6E18)',
        boxShadow: '0 6px 16px rgba(94,156,44,0.35)',
      }}
    >
      NN
    </div>
  );
}

export function BrandWordmark() {
  return (
    <div className="flex items-center gap-2.5">
      <BrandMark size={34} />
      <div className="leading-tight">
        <div className="text-sm font-bold text-gray-900">NN Foods &amp; Spices</div>
        <div className="text-[10px] font-semibold uppercase tracking-wide text-brand-orange">
          Admin Panel
        </div>
      </div>
    </div>
  );
}
