'use client';

import { forwardRef } from 'react';
import { motion, HTMLMotionProps } from 'framer-motion';
import clsx from 'clsx';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'minimal' | 'outline' | 'soft';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends Omit<HTMLMotionProps<'button'>, 'ref'> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  href?: string;
  external?: boolean;
  children: React.ReactNode;
}

const variantStyles: Record<ButtonVariant, string> = {
  // Minimal: text only, very subtle hover
  minimal: `
    bg-transparent
    text-[#A8B4BC] font-medium
    hover:text-[#00D4D4]
  `,
  // Outline: thin border, no fill
  outline: `
    bg-transparent
    text-[#A8B4BC] font-medium
    border border-white/10
    hover:border-[#00D4D4]/25 hover:text-[#E8E4E0]
  `,
  // Soft: subtle background
  soft: `
    bg-white/[0.03]
    text-[#A8B4BC] font-medium
    hover:bg-white/[0.07] hover:text-[#E8E4E0]
  `,
  // Primary: coral/moon accent gradient
  primary: `
    bg-gradient-to-r from-[#E85A5A]/20 to-[#FF7B7B]/15
    text-[#E8E4E0] font-medium
    border border-[#E85A5A]/20
    hover:from-[#E85A5A]/30 hover:to-[#FF7B7B]/25
    hover:border-[#E85A5A]/30
  `,
  // Secondary: cyan/teal accent
  secondary: `
    bg-transparent
    border border-[#00D4D4]/20
    text-[#A8B4BC] font-medium
    hover:bg-[#00D4D4]/5
    hover:border-[#00D4D4]/30
    hover:text-[#00D4D4]
  `,
  // Ghost: for nav items
  ghost: `
    bg-transparent
    text-[#A8B4BC] font-medium
    hover:text-[#00D4D4]
    hover:bg-white/[0.03]
  `,
};

const sizeStyles: Record<ButtonSize, string> = {
  sm: 'px-4 py-2 text-sm rounded-md',
  md: 'px-5 py-2.5 text-sm rounded-lg',
  lg: 'px-6 py-3 text-base rounded-lg',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      href,
      external = false,
      className,
      children,
      ...props
    },
    ref
  ) => {
    const baseStyles = `
      inline-flex items-center justify-center gap-2
      transition-all duration-200 ease-out
      focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#00D4D4]/50 focus-visible:ring-offset-2 focus-visible:ring-offset-[#0A1419]
      disabled:opacity-50 disabled:cursor-not-allowed
    `;

    const buttonContent = (
      <motion.button
        ref={ref}
        className={clsx(baseStyles, variantStyles[variant], sizeStyles[size], className)}
        whileHover={{ scale: 1.01 }}
        whileTap={{ scale: 0.99 }}
        {...props}
      >
        {children}
      </motion.button>
    );

    if (href) {
      const linkProps = external
        ? { target: '_blank', rel: 'noopener noreferrer' }
        : {};

      return (
        <motion.a
          href={href}
          className={clsx(baseStyles, variantStyles[variant], sizeStyles[size], className)}
          whileHover={{ scale: 1.01 }}
          whileTap={{ scale: 0.99 }}
          {...linkProps}
        >
          {children}
        </motion.a>
      );
    }

    return buttonContent;
  }
);

Button.displayName = 'Button';
