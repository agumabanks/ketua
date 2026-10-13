// Data Deletion Admin Panel
$(document).ready(function () {
    var appUrl = $('#appUrl').val();

    // Open status update modal
    $(document).on('click', '.update-status-btn', function () {
        var id = $(this).data('id');
        var status = $(this).data('status');
        var notes = $(this).data('notes') || '';

        $('#modal_id').val(id);
        $('#modal_status').val(status);
        $('#modal_notes').val(notes);
        $('#modalReqId').text('#' + id);
        $('#statusModal').modal('show');
    });

    // Save status update
    $('#modalSaveBtn').on('click', function () {
        var id = $('#modal_id').val();
        var status = $('#modal_status').val();
        var notes = $('#modal_notes').val();

        $.ajax({
            url: appUrl + 'data-deletion-admin/status/' + id,
            method: 'POST',
            data: {
                _token: $('meta[name="csrf-token"]').attr('content'),
                status: status,
                admin_notes: notes
            },
            success: function (response) {
                if (response.status) {
                    iziToast.success({
                        title: 'Updated',
                        message: response.message,
                        position: 'topRight'
                    });
                    $('#statusModal').modal('hide');
                    setTimeout(function () { location.reload(); }, 1000);
                } else {
                    iziToast.error({
                        title: 'Error',
                        message: response.message,
                        position: 'topRight'
                    });
                }
            },
            error: function () {
                iziToast.error({
                    title: 'Error',
                    message: 'Something went wrong. Please try again.',
                    position: 'topRight'
                });
            }
        });
    });

    // User lookup (opens in new tab from the link)
    $(document).on('click', '.lookup-btn', function (e) {
        // Default behaviour already opens in new tab — nothing extra needed.
    });
});
