/* Report viewer: charts, "Group by" auto-submit, copy link, print. */
(function () {
  'use strict';
  var palette = ['#f5c842', '#2dd4bf', '#a78bfa', '#f87171', '#60a5fa', '#34d399', '#fb923c', '#e879f9'];

  document.querySelectorAll('canvas[data-report-chart]').forEach(function (canvas) {
    var source = document.getElementById(canvas.getAttribute('data-report-chart'));
    if (!source || !window.Chart) return;
    var spec;
    try { spec = JSON.parse(source.textContent); } catch (e) { return; }
    new window.Chart(canvas, {
      type: spec.kind === 'bar' ? 'bar' : 'line',
      data: {
        labels: spec.labels,
        datasets: spec.datasets.map(function (d, i) {
          var color = palette[i % palette.length];
          return {label: d.label, data: d.data, borderColor: color, backgroundColor: color + '99', tension: 0.25, spanGaps: true};
        }),
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {mode: 'index', intersect: false},
        plugins: {legend: {labels: {color: '#cbd5e1'}}, title: {display: Boolean(spec.title), text: spec.title, color: '#e2e8f0'}},
        scales: {
          x: {ticks: {color: '#94a3b8'}, grid: {color: 'rgba(255,255,255,0.06)'}},
          y: {ticks: {color: '#94a3b8'}, grid: {color: 'rgba(255,255,255,0.06)'}},
        },
      },
    });
  });

  var copy = document.querySelector('[data-copy-link]');
  if (copy) {
    copy.addEventListener('click', function () {
      var url = location.href.replace(/([?&])(export|dataset)=[^&]*/g, '$1').replace(/[?&]+$/, '');
      var done = function () { window.ConsoleUI && window.ConsoleUI.toast('Link copied. Anyone with access sees this report with the same parameters.', {tone: 'success'}); };
      if (navigator.clipboard) navigator.clipboard.writeText(url).then(done, function () { window.prompt('Copy this link', url); });
      else window.prompt('Copy this link', url);
    });
  }
})();
