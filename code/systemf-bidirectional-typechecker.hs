import Debug.Trace

data Type = Arrow Type Type | TVar String
  | Forall String Type
  deriving (Eq, Show )
data Term =
    Var String 
  | Abs String Term 
  | App Term Term
  | HasType Term Type
  | TAbs String Term
  | TApp Term Type
  deriving (Eq, Show)

(⇒) = Arrow
(·) = App
(&) = HasType
fn = Abs
template = TAbs

type Context = ([(String, Type)], [String])

withVar :: Context -> String -> Type -> Context
withVar (v, t) name ty = ((name, ty) : v, t)

withType :: Context -> String -> Context
withType (v, t) ty = (v, ty : t)

substituteType :: String -> Type -> Type -> Type
substituteType name value = subst
  where
    subst (Arrow a b) = Arrow (subst a) (subst b)
    subst (Forall s t) | s == name = Forall s t
    subst (Forall s t) = Forall s (subst t)
    subst (TVar t) | t == name = value
    subst (TVar t) = TVar t

check :: Context -> Term -> Type -> Bool
infer :: Context -> Term -> Maybe Type

infer ( (w, t) : _, _ ) (Var v) | v == w = Just t
infer ( head : tail, x ) (Var v) = infer (tail, x) (Var v)


infer ctx (App (Abs v fn) arg) = do
  a <- infer ctx arg ;
  b <- infer (withVar ctx v a) fn ;
  return $ Arrow a b

infer ctx (App fn arg) = do
  Arrow a b <- infer ctx fn ; if check ctx arg a then return b else Nothing
infer ctx (HasType term ty) = if check ctx term ty then Just ty else Nothing

infer ctx (TAbs ty term) = do
  t <- infer (withType ctx ty) term ;
  return (Forall ty t)

infer ctx (TApp term ty) = do
  Forall typevar abstract <- infer ctx term ;
  return (substituteType typevar ty abstract)

infer ctx term | trace (show ctx ++ "  " ++ show term) False = undefined

check ctx (Abs v t) (Arrow α β) = check (withVar ctx v α) t β
check ctx (TAbs v term) (Forall w ty) | w == v = check (withType ctx v) term ty
check ctx term ty = (infer ctx term) == Just ty


ofType ty (v, t) = t == ty

derive :: Context -> Type -> Maybe Term
derive ctx ty | any (ofType ty) (fst ctx) = Just (Var $ fst (filter (ofType ty) (fst ctx) !! 0))
--derive ctx TBool = Just (Value False)
derive ctx (Arrow a b) = do
  fn <- derive (withVar ctx v a) b ;
  return $ Abs v fn
  where v = newVar ctx
        newVar ctx = "v" ++ (show (length ctx))

tA = TVar "a"
bool = Forall "a" (tA ⇒ (tA ⇒ tA))
true = TAbs "a" (fn "x" (fn "y" (Var "x") ))
false = TAbs "a" (fn "x" (fn "y" (Var "y")))
