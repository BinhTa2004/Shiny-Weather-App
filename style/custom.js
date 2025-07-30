$(function() {
  $('.floating-panel').draggable();
  $('.info-box').draggable();
  $(document).on('click', '.close-btn', function() {
    $('#weatherBox').hide();
  });
});
