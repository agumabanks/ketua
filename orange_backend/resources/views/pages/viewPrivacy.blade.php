@extends('include.app')
@section('header')
    <script src="{{ asset('asset/script/viewPrivacy.js') }}"></script>
@endsection

@section('content')
    <div class="card mt-3">
        <div class="card-header">
            <h4>{{ __('Privacy Policy') }} <a target="_blank" class="btn btn-primary"
                    href="{{ env('APP_URL') . 'privacypolicy' }}">{{ __('Click Here') }}</a></h4>
        </div>
        <div class="card-body">

            <form Autocomplete="off" class="form-group form-border" action="" method="post" id="privacy" required>
                @csrf

                <div class="form-group">
                    <label>{{ __('Content') }}</label>
                    <textarea class="summernote-simple" name="content">
        <?php
        echo e($data);
        ?>

                    </textarea>

                </div>
                <div class="form-group">
                    <input type="hidden" name="publish" value="0"><label><input type="checkbox" name="publish" value="1"> Publish after completing the review</label><br><input class="btn btn-primary mr-1" type="submit" value="Save">
                </div>
            </form>
        </div>
    </div>
@endsection
