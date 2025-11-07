"use client";

import React, { useState, useCallback } from "react";
import { CardSelectorOverlay, CardOption } from "@/components/ui/card-selector-overlay";

interface UseCardSelectorOptions {
  title?: string;
  subtitle?: string;
  maxWidth?: string;
  gridCols?: "1" | "2" | "3" | "4";
}

export function useCardSelector(options: UseCardSelectorOptions = {}) {
  const [isOpen, setIsOpen] = useState(false);
  const [cards, setCards] = useState<CardOption[]>([]);
  const [resolvePromise, setResolvePromise] = useState<
    ((card: CardOption | null) => void) | null
  >(null);

  const selectCard = useCallback(
    (cardOptions: CardOption[]): Promise<CardOption | null> => {
      return new Promise((resolve) => {
        setCards(cardOptions);
        setResolvePromise(() => resolve);
        setIsOpen(true);
      });
    },
    []
  );

  const handleSelect = useCallback(
    (card: CardOption) => {
      setIsOpen(false);
      if (resolvePromise) {
        resolvePromise(card);
        setResolvePromise(null);
      }
    },
    [resolvePromise]
  );

  const handleClose = useCallback(() => {
    setIsOpen(false);
    if (resolvePromise) {
      resolvePromise(null);
      setResolvePromise(null);
    }
  }, [resolvePromise]);

  const overlay: React.ReactNode = (
    <CardSelectorOverlay
      isOpen={isOpen}
      onClose={handleClose}
      onSelect={handleSelect}
      cards={cards}
      title={options.title}
      subtitle={options.subtitle}
      maxWidth={options.maxWidth}
      gridCols={options.gridCols}
    />
  );

  return {
    selectCard,
    overlay
  };
}

