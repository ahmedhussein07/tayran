package com.tayran.controller.admin;

import com.tayran.config.security.AuthUser;
import com.tayran.model.ResponsePojo;
import com.tayran.model.admin.AdminDtos.CreateAdminRequest;
import com.tayran.model.admin.AdminDtos.ResetPasswordRequest;
import com.tayran.model.admin.AdminDtos.UpdateAdminRequest;
import com.tayran.service.AdminUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/users")
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public ResponseEntity<ResponsePojo> list() {
        return ResponseEntity.ok(ResponsePojo.ok(adminUserService.list()));
    }

    @PostMapping
    public ResponseEntity<ResponsePojo> create(@RequestBody @Valid CreateAdminRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(adminUserService.create(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponsePojo> update(@AuthenticationPrincipal AuthUser admin, @PathVariable long id,
                                               @RequestBody @Valid UpdateAdminRequest request) {
        return ResponseEntity.ok(ResponsePojo.ok(adminUserService.update(admin.id(), id, request)));
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<ResponsePojo> resetPassword(@PathVariable long id, @RequestBody @Valid ResetPasswordRequest request) {
        adminUserService.resetPassword(id, request.password());
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponsePojo> delete(@AuthenticationPrincipal AuthUser admin, @PathVariable long id) {
        adminUserService.delete(admin.id(), id);
        return ResponseEntity.ok(ResponsePojo.ok(null));
    }
}
