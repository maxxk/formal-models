data LType = TBool | TArrow LType LType | TVar String  deriving (Eq, Show )
data Term = Value Bool | Var String | Abs String Term |  App Term Term | HasType Term LType deriving (Eq, Show)

(⇒) = TArrow
(·) = App
(&) = HasType
fn = Abs

type Context = [(String, LType)]
-- Bool -> Bool = TArrow TBool TBool
-- λ x. true = Abs "x" (Value true)
-- Just x - значение x или Nothing
check :: Context -> Term -> LType -> Bool
infer :: Context -> Term -> Maybe LType

infer _ (Value _) = Just TBool
infer ( (w, t) : _ ) (Var v) | v == w = Just t
infer ( head : tail ) (Var v) = infer tail (Var v)

infer ctx (App (Abs v fn) arg) = do
  a <- infer ctx arg ;
  b <- infer ((v, a) : ctx) fn ;
  return $ TArrow a b

infer ctx (App fn arg) = do
  TArrow a b <- infer ctx fn ; if check ctx arg a then return b else Nothing
infer ctx (HasType term ty) = if check ctx term ty then Just ty else Nothing

check ctx (Abs v t) (TArrow α β) = check ((v, α) : ctx) t β
check ctx term ty = (infer ctx term) == Just ty


ofType ty (v, t) = t == ty

derive :: Context -> LType -> Maybe Term
derive ctx ty | any (ofType ty) ctx = Just (Var $ fst (filter (ofType ty) ctx !! 0))
derive ctx TBool = Just (Value False)
derive ctx (TArrow a b) = do
  fn <- derive ((v, a) : ctx) b ;
  return $ Abs v fn
  where v = newVar ctx
        newVar ctx = "v" ++ (show (length ctx))
