package com.tayran.service;

import com.tayran.model.admin.AdminDtos.AdminUserDto;
import com.tayran.model.admin.AdminDtos.CreateAdminRequest;
import com.tayran.model.admin.AdminDtos.UpdateAdminRequest;

import java.util.List;

public interface AdminUserService {

    List<AdminUserDto> list();

    AdminUserDto create(CreateAdminRequest request);

    AdminUserDto update(long currentAdminId, long id, UpdateAdminRequest request);

    void resetPassword(long id, String password);

    void delete(long currentAdminId, long id);
}
