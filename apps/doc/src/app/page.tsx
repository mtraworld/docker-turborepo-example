"use client";

const title = process.env.NEXT_PUBLIC_TITLE ?? "";

export default function Doc() {
  return (
    <div>
      <h1>{title}</h1>
      <p>Hello {title}</p>
    </div>
  );
}
