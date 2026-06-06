"use strict";

const gallerySection = document.getElementById("gallery");
const gallery = document.getElementById("photo-gallery");
const modal = document.getElementById("image-modal");
const modalImage = document.getElementById("modal-image");
const modalCloseButton = document.getElementById("image-modal-close");
let modalTrigger = null;
let modalCloseTimer = null;

function isSafePhotoPath(value) {
  return typeof value === "string"
    && /^assets\/photos\/[a-zA-Z0-9._-]+\.(?:avif|jpe?g|png|webp)$/i.test(value);
}

function renderGallery(photos) {
  if (!gallerySection || !gallery || !Array.isArray(photos) || photos.length === 0) return;

  const fragment = document.createDocumentFragment();
  for (const photo of photos) {
    if (!photo || !isSafePhotoPath(photo.src)) continue;

    const figure = document.createElement("figure");
    figure.className = "panel gallery-card";

    const imageFrame = document.createElement("div");
    imageFrame.className = "gallery-image-frame";

    const image = document.createElement("img");
    image.src = photo.src;
    image.alt = String(photo.alt || photo.caption || "Archer Tsai photo");
    image.className = "gallery-image";
    image.loading = "lazy";
    imageFrame.appendChild(image);
    figure.appendChild(imageFrame);

    if (photo.caption) {
      const caption = document.createElement("figcaption");
      caption.className = "gallery-caption";
      caption.textContent = String(photo.caption);
      figure.appendChild(caption);
    }

    fragment.appendChild(figure);
  }

  if (!fragment.childNodes.length) return;
  gallery.replaceChildren(fragment);
  gallerySection.classList.remove("hidden");
}

if (gallerySection && gallery) {
  fetch("photos.json", {
    cache: "no-store",
    credentials: "same-origin"
  })
    .then((response) => {
      if (!response.ok) throw new Error("Unable to load photos");
      return response.json();
    })
    .then(renderGallery)
    .catch(() => gallerySection.classList.add("hidden"));
}

function openModal(trigger) {
  if (!modal || !modalImage || !modalCloseButton) return;
  const imageSrc = trigger.dataset.modalSrc;
  if (!/^assets\/projects\/[a-zA-Z0-9._-]+\.(?:jpe?g|png|webp)$/i.test(imageSrc || "")) return;

  modalTrigger = trigger;
  clearTimeout(modalCloseTimer);
  modalImage.src = imageSrc;
  modalImage.alt = trigger.dataset.modalAlt || trigger.querySelector("img")?.alt || "專案成果放大圖";
  modal.classList.remove("hidden");
  modal.classList.add("flex");
  modal.setAttribute("aria-hidden", "false");
  void modal.offsetWidth;
  modal.classList.remove("opacity-0");
  modalImage.classList.remove("scale-95");
  modalImage.classList.add("scale-100");
  document.body.classList.add("modal-open");
  modalCloseButton.focus();
}

function closeModal() {
  if (!modal || !modalImage || modal.classList.contains("hidden")) return;
  modal.classList.add("opacity-0");
  modalImage.classList.remove("scale-100");
  modalImage.classList.add("scale-95");
  modal.setAttribute("aria-hidden", "true");
  modalCloseTimer = setTimeout(() => {
    modal.classList.add("hidden");
    modal.classList.remove("flex");
    modalImage.src = "";
    document.body.classList.remove("modal-open");
    modalTrigger?.focus();
    modalTrigger = null;
  }, 300);
}

document.querySelectorAll("[data-modal-src]").forEach((trigger) => {
  trigger.addEventListener("click", () => openModal(trigger));
});

modal?.addEventListener("click", closeModal);
modalImage?.addEventListener("click", (event) => event.stopPropagation());
modalCloseButton?.addEventListener("click", (event) => {
  event.stopPropagation();
  closeModal();
});

document.addEventListener("keydown", (event) => {
  if (!modal || modal.classList.contains("hidden")) return;
  if (event.key === "Escape") closeModal();
  if (event.key === "Tab") {
    event.preventDefault();
    modalCloseButton?.focus();
  }
});
