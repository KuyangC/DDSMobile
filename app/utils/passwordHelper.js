    // Simple password helper untuk demo
// Di production, gunakan bcrypt yang proper

export const hashPassword = (password) => {
  // Simple encoding for demo
  return btoa(password);
};

export const comparePassword = (plainPassword, hashedPassword) => {
  return btoa(plainPassword) === hashedPassword;
};