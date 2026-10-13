<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="csrf-token" content="<?php echo e(csrf_token()); ?>">
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
    <title><?php echo Session::get('app_name'); ?></title>
    <link rel='shortcut icon' type='image/x-icon' href="<?php echo e(asset('asset/img/favicon.png')); ?>" style="width: 2px !important;" />

    <link rel="stylesheet" href="<?php echo e(asset('asset/css/bootstrap.min.css')); ?>" type="text/css" />
    <link rel="stylesheet" href="<?php echo e(asset('asset/cdncss/iziToast.css')); ?>" type="text/css" />
    <link rel="stylesheet" href="<?php echo e(asset('asset/css/style.css')); ?>">
</head>

<body>
    <div class="login-page">
        <div class="container">
            <div class="row align-items-center justify-content-center mt-5">
                <div class="col-lg-5 col-md-5 col-sm-12">
                    <div class="login-box">
                        <div class="mb-3"><a href="<?php echo e(url('/')); ?>" style="color:#9a97a8;font-size:14px">&larr; Back to KETUA home</a></div>
                        <div class="text-center mb-4">
                            <h3> <?php echo e(Session::get('app_name')); ?> <small style="font-size:14px;color:#9a97a8">Admin Panel</small></h3>
                        </div>
                        <div class="card login-card">
                            <div class="card-header">
                                <h4><?php echo e(__('Log In')); ?></h4>
                            </div>
                            <div class="card-body">
                                <form id="loginForm" action="javascript:void(0);">
                                    <?php echo csrf_field(); ?>
                                    <div class="mb-3">
                                        <label for="user_name" class="form-label"><?php echo e(__('Username')); ?></label>
                                        <input class="form-control" type="text" id="user_name" name="user_name" required="" placeholder="Enter your username" autocomplete>
                                    </div>
                                    <div class="mb-3">
                                        <label for="user_password" class="form-label"><?php echo e(__('Password')); ?></label>
                                        <div class="position-relative">
                                            <input type="password" id="user_password" name="user_password" class="form-control" placeholder="Enter your password" autocomplete>
                                            <div class="password-icon">
                                                <i data-feather="eye" class="eye1"></i>
                                                <i data-feather="eye-off" class="eye-off1"></i>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="mb-0 text-center">
                                        <button class="btn btn-primary w-100 shadow-none" type="submit"> <?php echo e(__('Log In')); ?> </button>
                                    </div>
                                    <hr>
                                    <div class="">
                                        <div class="text-center">
                                            <a href="javascript:;" data-bs-toggle="modal" data-bs-target="#forgotPasswordModal"> <?php echo e(__('Forgot Password')); ?>? </a>
                                        </div>
                                    </div>
                                </form>
                            </div>
                        </div>
                        <div class="text-center mt-3">
                            <small style="color:#9a97a8">
                                <a href="<?php echo e(route('privacypolicy')); ?>" style="color:#9a97a8">Privacy Policy</a> &middot;
                                <a href="<?php echo e(route('termsOfUse')); ?>" style="color:#9a97a8">Terms</a> &middot;
                                <a href="<?php echo e(route('csae')); ?>" style="color:#9a97a8">Child Safety (CSAE)</a> &middot;
                                <a href="<?php echo e(route('dataDeletion.create')); ?>" style="color:#9a97a8">Request Data Deletion</a>
                            </small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="forgotPasswordModal" tabindex="-1" aria-labelledby="addGenreModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel"><?php echo e(__('Forgot Password')); ?></h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="forgotPasswordForm" method="POST">
                    <?php echo csrf_field(); ?>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="database_username" class="form-label"><?php echo e(__('Database Username')); ?></label>
                            <input class="form-control" type="text" id="database_username" name="database_username" placeholder="Enter your database username" required="" autocomplete>
                        </div>
                        <div class="mb-3">
                            <label for="database_password" class="form-label"><?php echo e(__('Database Password')); ?></label>
                            <div class="position-relative">
                                <input type="password" id="database_password" name="database_password" class="form-control" placeholder="Enter your database password" required="" autocomplete>
                                <div class="password-icon">
                                    <i data-feather="eye" class="eye4"></i>
                                    <i data-feather="eye-off" class="eye-off4"></i>
                                </div>
                            </div>
                        </div>
                        <hr>
                        <div class="mb-3">
                            <label for="new_password" class="form-label"><?php echo e(__('New Password')); ?></label>
                            <div class="position-relative">
                                <input type="password" id="new_password" name="new_password" class="form-control" placeholder="Enter new your password" required="" autocomplete>
                                <div class="password-icon">
                                    <i data-feather="eye" class="eye2"></i>
                                    <i data-feather="eye-off" class="eye-off2"></i>
                                </div>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label for="confirm_password" class="form-label"><?php echo e(__('Confirm Password')); ?></label>
                            <div class="position-relative">
                                <input type="password" id="confirm_password" name="confirm_password" class="form-control" placeholder="Enter confirm your password" required="" autocomplete>
                                <div class="password-icon">
                                    <i data-feather="eye" class="eye3"></i>
                                    <i data-feather="eye-off" class="eye-off3"></i>
                                </div>
                            </div>
                        </div>

                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light" data-bs-dismiss="modal"><?php echo e(__('Close')); ?></button>
                        <button type="submit" class="btn btn-primary">
                            <?php echo e(__('Save')); ?>

                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- scripts -->
    <input type="hidden" value="<?php echo e(config('app.url')); ?>" id="appUrl">
    <script src="<?php echo e(asset('asset/js/jquery-3.7.1.min.js')); ?>"></script>
    <script src="<?php echo e(asset('asset/cdnjs/iziToast.min.js')); ?>"></script>
    <script src="<?php echo e(asset('asset/js/bootstrap.min.js')); ?>"></script>
    <script src="<?php echo e(asset('asset/js/app.min.js')); ?>"></script>
    <script src="<?php echo e(asset('asset/js/custom.js')); ?>"></script>
    <script src="<?php echo e(asset('asset/js/scripts.js')); ?>"></script>
    <script src="<?php echo e(asset('asset/script/app.js')); ?>"></script>

    <script src="<?php echo e(asset('asset/script/env.js') . '?v=20261009-1'); ?>"></script>
    <script src="<?php echo e(asset('asset/script/login.js')); ?>"></script>

</body>

</html><?php /**PATH /var/www/ketua.sanaa.co/orange_backend/resources/views/login/login.blade.php ENDPATH**/ ?>