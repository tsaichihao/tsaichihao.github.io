"use strict";

/* Evidence dialog (native <dialog>) */
(() => {
  const dialog = document.getElementById("evidence-dialog");
  const image = document.getElementById("evidence-image");
  const title = document.getElementById("evidence-title");
  const close = document.getElementById("dialog-close");
  if (!dialog || !image || !title || !close || typeof dialog.showModal !== "function") return;

  const allowed = /^assets\/projects\/[a-zA-Z0-9._-]+\.(?:jpe?g|png|webp)$/i;
  let opener = null;

  document.querySelectorAll("[data-image]").forEach((button) => {
    button.addEventListener("click", () => {
      const source = button.dataset.image || "";
      if (!allowed.test(source)) return;
      opener = button;
      image.src = source;
      image.alt = button.dataset.caption || "成果截圖";
      title.textContent = button.dataset.caption || "成果截圖";
      dialog.showModal();
      close.focus();
    });
  });

  close.addEventListener("click", () => dialog.close());

  dialog.addEventListener("close", () => {
    image.removeAttribute("src");
    if (opener) opener.focus();
    opener = null;
  });

  dialog.addEventListener("click", (event) => {
    if (event.target !== dialog) return;
    const rect = dialog.getBoundingClientRect();
    const outside = event.clientX < rect.left || event.clientX > rect.right
      || event.clientY < rect.top || event.clientY > rect.bottom;
    if (outside) dialog.close();
  });
})();

/* Photo gallery (photos.json, written by tools/update-photo.ps1). Hidden while empty. */
(() => {
  const section = document.getElementById("gallery");
  const grid = document.getElementById("photo-gallery");
  if (!section || !grid) return;

  const isSafePhotoPath = (value) => typeof value === "string"
    && /^assets\/photos\/[a-zA-Z0-9._-]+\.(?:avif|jpe?g|png|webp)$/i.test(value);

  fetch("photos.json", { cache: "no-store", credentials: "same-origin" })
    .then((response) => {
      if (!response.ok) throw new Error("Unable to load photos");
      return response.json();
    })
    .then((photos) => {
      if (!Array.isArray(photos) || photos.length === 0) return;
      const fragment = document.createDocumentFragment();
      for (const photo of photos) {
        if (!photo || !isSafePhotoPath(photo.src)) continue;
        const figure = document.createElement("figure");
        figure.className = "gallery-card";
        const frame = document.createElement("div");
        frame.className = "gallery-image-frame";
        const img = document.createElement("img");
        img.src = photo.src;
        img.alt = String(photo.alt || photo.caption || "Archer Tsai photo");
        img.className = "gallery-image";
        img.loading = "lazy";
        frame.appendChild(img);
        figure.appendChild(frame);
        if (photo.caption) {
          const caption = document.createElement("figcaption");
          caption.className = "gallery-caption";
          caption.textContent = String(photo.caption);
          figure.appendChild(caption);
        }
        fragment.appendChild(figure);
      }
      if (!fragment.childNodes.length) return;
      grid.replaceChildren(fragment);
      document.getElementById("gallery-empty")?.setAttribute("hidden", "");
      section.classList.remove("hidden");
    })
    .catch(() => section.classList.add("hidden"));
})();
