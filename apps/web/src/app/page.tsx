"use client";

const title = process.env.NEXT_PUBLIC_TITLE ?? "";

export default function Web() {
  return (
    <div>
      <h1>{title}</h1>
    </div>
  );
}
