package kz.jemis.identity;

import java.util.UUID;

/** Authenticated principal derived from the access token. */
public record AuthUser(UUID id, Role role) {}
