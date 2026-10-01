window.addEventListener('flutter-first-frame', () => {
  document.querySelector('#loading')?.remove();
});

window.setTimeout(() => {
  const note = document.querySelector('#slow');
  if (note) note.style.display = 'block';
}, 15000);
